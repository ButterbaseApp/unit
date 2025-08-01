#!/bin/bash

# Script to test Avram integration
# This installs development dependencies and runs the integration tests

echo "Installing development dependencies..."
shards install

echo -e "\nTesting Avram integration compilation..."
crystal run test_avram_integration.cr

echo -e "\nRunning Avram integration specs..."
crystal spec spec/avram_integration_spec.cr

echo -e "\nAvram integration testing complete!"