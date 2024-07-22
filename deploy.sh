#!/bin/bash

# Login no AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 135218620329.dkr.ecr.us-east-1.amazonaws.com