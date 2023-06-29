### Nginx ###
FROM python:3.9-slim
RUN apt-get update && apt-get install apt-transport-https && apt-get -y install vim
RUN mkdir powerops
WORKDIR powerops
RUN mkdir cert
RUN mkdir docs
COPY ["requirements.txt","config.yml","_poweropsmain.py","run_powerops", "/powerops"] 
COPY /lib /powerops/lib

RUN chmod +x run_powerops
RUN pip3 install -r requirements.txt

EXPOSE 22