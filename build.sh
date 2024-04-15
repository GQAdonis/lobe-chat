#!/bin/bash

cp ./env/.env ./.env

docker build -t tribehealth/lobe-chat:v0.0.5 --push --platform=linux/amd64  .

rm ./.env
