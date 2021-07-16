# Powerops
This project was generated with [Angular CLI](https://github.com/angular/angular-cli) version 11.1.3.

## Prerequisites
Have Docker installed

## Create Container
From the folder main folder, run  the following command:

docker build -t powerops .

## Run Docker

Run the following command:

docker run -it -d --name powerops -p 8100:80 -p8080:8080  powerops

## Access Powerops

http://localhost:8100