#!/bin/bash

# Unified build script for guestbook components
# Usage: ./build.sh [--component=backend|frontend|all] [--registry=127.0.0.1:5000] [--no-test] [--help]

set -e  # Exit on any error

# Default configuration
COMPONENT="all"
LOCAL_REGISTRY="127.0.0.1:5000"
RUN_TESTS=true
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Component configurations

# Component configurations
get_component_info() {
    local comp_name=$1
    case "$comp_name" in
        "backend")
            echo "src/backend:python-guestbook-backend:back.py"
            ;;
        "frontend")
            echo "src/frontend:python-guestbook-frontend:front.py"
            ;;
        *)
            echo "" # Return empty for unknown components
            ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Guestbook Build Script"
    echo "======================"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --component=COMP    Component to build: backend, frontend, or all (default: all)"
    echo "  --registry=URL      Container registry URL (default: 127.0.0.1:5000)"
    echo "  --no-test          Skip running tests"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Build all components"
    echo "  $0 --component=backend               # Build only backend"
    echo "  $0 --component=frontend --no-test    # Build frontend without tests"
    echo "  $0 --registry=my-registry.com:5000   # Use custom registry"
    echo ""
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --component=*)
            COMPONENT="${arg#*=}"
            ;;
        --registry=*)
            LOCAL_REGISTRY="${arg#*=}"
            ;;
        --no-test)
            RUN_TESTS=false
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown argument: $arg${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate component
if [[ "$COMPONENT" != "all" && -z "$(get_component_info "$COMPONENT")" ]]; then
    echo -e "${RED}❌ Invalid component: $COMPONENT${NC}"
    echo -e "${YELLOW}Available components: backend, frontend, all${NC}"
    exit 1
fi

# Function to build a single component
build_component() {
    local comp_name=$1
    local comp_info=$(get_component_info "$comp_name")
    
    IFS=':' read -r comp_dir image_name main_file <<< "$comp_info"
    
    echo -e "${BLUE}🚀 Building $comp_name component${NC}"
    echo "=================================="
    
    # Check if component directory exists
    if [ ! -d "$comp_dir" ]; then
        echo -e "${RED}❌ Component directory not found: $comp_dir${NC}"
        return 1
    fi
    
    # Change to component directory
    cd "$comp_dir"
    echo -e "${GREEN}📁 Changed to $comp_name directory:\n    $(pwd)${NC}"
    
    # Run tests using Makefile
    if [ "$RUN_TESTS" = true ]; then
        echo -e "${YELLOW}🧪 Running tests for $comp_name...${NC}"
        if make check; then
            echo -e "${GREEN}✅ Checks complete for $comp_name${NC}"
        else
            echo -e "${RED}❌ Checks failed for $comp_name! Build aborted.${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Skipping tests for $comp_name${NC}"
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "Dockerfile" ]; then
        echo -e "${RED}❌ Dockerfile not found in $comp_name directory${NC}"
        return 1
    fi
    
    # Prepare image tags
    image_latest="${LOCAL_REGISTRY}/${image_name}:latest"
    image_sha="${LOCAL_REGISTRY}/${image_name}:${GIT_SHA}"
    
    # Build image with docker build
    echo -e "${YELLOW}🐳 Building $comp_name image...${NC}"
    echo "Git SHA: $GIT_SHA"
    
    if docker build -t "$image_latest" -t "$image_sha" .; then
        echo -e "${GREEN}✅ $comp_name image built successfully${NC}"
    else
        echo -e "${RED}❌ Docker build failed for $comp_name!${NC}"
        return 1
    fi
    
    # Push both tags to registry
    echo -e "${YELLOW}📤 Pushing $comp_name images to registry...${NC}"
    if docker push "$image_latest" && docker push "$image_sha"; then
        echo -e "${GREEN}✅ $comp_name images pushed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to push $comp_name images to registry${NC}"
        return 1
    fi
    
    # Verify image in registry
    echo -e "${YELLOW}🔍 Verifying $comp_name image in registry...${NC}"
    if curl -f "http://${LOCAL_REGISTRY}/v2/${image_name}/tags/list" 2>/dev/null | grep -q "latest"; then
        echo -e "${GREEN}✅ $comp_name image verified in registry${NC}"
    else
        echo -e "${RED}❌ $comp_name image not found in registry${NC}"
        return 1
    fi
    
    echo -e "${GREEN}🎉 $comp_name build completed successfully!${NC}"
    echo ""
    
    # Return to original directory
    cd - >/dev/null
}

# Main execution
echo -e "${BLUE}🚀 Guestbook Build Pipeline${NC}"
echo "=============================="
echo "Component(s): $COMPONENT"
echo "Registry: $LOCAL_REGISTRY"
echo "Run tests: $RUN_TESTS"
echo "Git SHA: $GIT_SHA"
echo ""

# Check if local registry is running
echo -e "${YELLOW}🔍 Checking registry availability...${NC}"
if curl -f "http://${LOCAL_REGISTRY}/v2/" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Registry is running at $LOCAL_REGISTRY${NC}"
else
    echo -e "${RED}❌ Registry not available at $LOCAL_REGISTRY${NC}"
    echo -e "${YELLOW}💡 Start registry with: docker run -d -p 5000:5000 --name registry registry:2${NC}"
    exit 1
fi

# Build components
if [ "$COMPONENT" = "all" ]; then
    # Build all components
    for comp in backend frontend; do
        if ! build_component "$comp"; then
            echo -e "${RED}❌ Failed to build $comp${NC}"
            exit 1
        fi
    done
else
    # Build specific component
    if ! build_component "$COMPONENT"; then
        echo -e "${RED}❌ Failed to build $COMPONENT${NC}"
        exit 1
    fi
fi

# Final summary
echo -e "${GREEN}🎉 Build pipeline completed successfully!${NC}"
echo "========================================"
echo "Registry: http://${LOCAL_REGISTRY}"
echo "Git SHA: $GIT_SHA"
echo "Images:"
echo "  Latest: $image_latest"
echo "  SHA:    $image_sha"
echo ""