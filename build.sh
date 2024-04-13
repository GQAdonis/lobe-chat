#!/bin/bash

source ./env/.env

docker build -t tribehealth/lobe-chat:v0.0.2 --push --platform=linux/amd64  .