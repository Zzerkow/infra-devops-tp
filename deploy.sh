#!/bin/bash
set -e

echo "==================================="
echo "GLPI Stack Deployment Script"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform is not installed. Please install it first.${NC}"
        exit 1
    fi

    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}Ansible is not installed. Please install it first.${NC}"
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed. Please install it first.${NC}"
        exit 1
    fi

    echo -e "${GREEN}All prerequisites are installed.${NC}"
}

# Initialize Terraform
init_terraform() {
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    cd terraform
    terraform init
    cd ..
    echo -e "${GREEN}Terraform initialized.${NC}"
}

# Apply Terraform
apply_terraform() {
    echo -e "${YELLOW}Applying Terraform configuration...${NC}"
    cd terraform
    terraform apply -auto-approve
    cd ..
    echo -e "${GREEN}Terraform applied.${NC}"
}

# Run Ansible playbook
run_ansible() {
    echo -e "${YELLOW}Running Ansible playbook...${NC}"
    cd ansible
    ansible-playbook playbook.yml
    cd ..
    echo -e "${GREEN}Ansible playbook completed.${NC}"
}

# Deploy locally (for testing)
deploy_local() {
    echo -e "${YELLOW}Deploying locally for testing...${NC}"

    # Initialize Swarm if not already
    if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
        echo "Initializing Docker Swarm..."
        docker swarm init || true
    fi

    # Create volumes
    echo "Creating Docker volumes..."
    docker volume create mariadb_data || true
    docker volume create glpi_data || true
    docker volume create glpi_plugins || true
    docker volume create letsencrypt_certs || true

    # Create network
    echo "Creating overlay network..."
    docker network create --driver overlay --attachable glpi_network || true

    # Deploy stack
    echo "Deploying stack..."
    cd docker
    docker stack deploy -c docker-compose.yml glpi
    cd ..

    echo -e "${GREEN}Local deployment completed.${NC}"
    echo ""
    echo "Stack services:"
    docker stack services glpi
    echo ""
    echo -e "${YELLOW}Access GLPI at: http://localhost${NC}"
}

# Destroy local deployment
destroy_local() {
    echo -e "${YELLOW}Destroying local deployment...${NC}"
    docker stack rm glpi || true
    sleep 10
    docker volume rm mariadb_data glpi_data glpi_plugins letsencrypt_certs || true
    docker network rm glpi_network || true
    echo -e "${GREEN}Local deployment destroyed.${NC}"
}

# Show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  check       Check prerequisites"
    echo "  terraform   Initialize and apply Terraform"
    echo "  ansible     Run Ansible playbook"
    echo "  local       Deploy locally for testing"
    echo "  destroy     Destroy local deployment"
    echo "  full        Full deployment (terraform + ansible)"
    echo "  help        Show this help"
    echo ""
}

# Main
case "${1:-help}" in
    check)
        check_prerequisites
        ;;
    terraform)
        check_prerequisites
        init_terraform
        apply_terraform
        ;;
    ansible)
        check_prerequisites
        run_ansible
        ;;
    local)
        deploy_local
        ;;
    destroy)
        destroy_local
        ;;
    full)
        check_prerequisites
        init_terraform
        apply_terraform
        run_ansible
        ;;
    help|*)
        show_help
        ;;
esac
