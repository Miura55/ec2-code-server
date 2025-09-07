#!/bin/bash

# VSCode Server CDK Development Environment Deployment Script

set -e

# Configuration
STACK_NAME="vscode-cdk-dev"
TEMPLATE_FILE="vscode-server-cdk-dev.yaml"
REGION="ap-northeast-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "Template file $TEMPLATE_FILE not found"
        exit 1
    fi
    
    print_info "Prerequisites check passed"
}

get_key_pairs() {
    aws ec2 describe-key-pairs --region $REGION --query 'KeyPairs[].KeyName' --output text 2>/dev/null || echo ""
}

deploy_stack() {
    local instance_type=${1:-t3.medium}
    local ami_id=${2:-ami-07faa35bbd2230d90}
    local key_pair_name=$3
    local allowed_cidr=${4:-0.0.0.0/0}
    
    print_info "Deploying CloudFormation stack: $STACK_NAME"
    
    aws cloudformation deploy \
        --template-file $TEMPLATE_FILE \
        --stack-name $STACK_NAME \
        --parameter-overrides \
            InstanceType=$instance_type \
            AmiId=$ami_id \
            KeyPairName=$key_pair_name \
            AllowedCIDR=$allowed_cidr \
        --capabilities CAPABILITY_IAM \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        print_info "Stack deployment completed successfully"
        show_outputs
    else
        print_error "Stack deployment failed"
        exit 1
    fi
}

show_outputs() {
    print_info "Retrieving stack outputs..."
    
    local outputs=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs' \
        --output table 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$outputs"
        
        # Get specific values
        local vscode_url=$(aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].Outputs[?OutputKey==`VSCodeServerURL`].OutputValue' \
            --output text 2>/dev/null)
        
        local password=$(aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].Outputs[?OutputKey==`VSCodeServerPassword`].OutputValue' \
            --output text 2>/dev/null)
        
        echo ""
        print_info "Quick Access:"
        echo "VSCode Server: $vscode_url"
        echo "Password: $password"
    fi
}

delete_stack() {
    print_warning "Deleting stack: $STACK_NAME"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
        print_info "Stack deletion initiated"
    fi
}

# Main script
case "${1:-deploy}" in
    "deploy")
        check_prerequisites
        
        # Get available key pairs
        key_pairs=$(get_key_pairs)
        if [ -z "$key_pairs" ]; then
            print_error "No EC2 key pairs found in region $REGION"
            print_info "Create a key pair first: aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem"
            exit 1
        fi
        
        echo "Available key pairs: $key_pairs"
        read -p "Enter key pair name: " key_pair_name
        
        if [ -z "$key_pair_name" ]; then
            print_error "Key pair name is required"
            exit 1
        fi
        
        read -p "Instance type (t3.medium): " instance_type
        instance_type=${instance_type:-t3.medium}
        
        read -p "AMI ID (ami-07faa35bbd2230d90): " ami_id
        ami_id=${ami_id:-ami-07faa35bbd2230d90}
        
        read -p "Allowed CIDR (0.0.0.0/0): " allowed_cidr
        allowed_cidr=${allowed_cidr:-0.0.0.0/0}
        
        deploy_stack "$instance_type" "$ami_id" "$key_pair_name" "$allowed_cidr"
        ;;
    
    "status")
        aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "Stack not found"
        ;;
    
    "outputs")
        show_outputs
        ;;
    
    "delete")
        delete_stack
        ;;
    
    *)
        echo "Usage: $0 [deploy|status|outputs|delete]"
        echo "  deploy  - Deploy the stack (default)"
        echo "  status  - Show stack status"
        echo "  outputs - Show stack outputs"
        echo "  delete  - Delete the stack"
        exit 1
        ;;
esac