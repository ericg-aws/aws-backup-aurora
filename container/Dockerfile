# purpose: general endpoint monitoring
# build: docker build -t ericstephengarcia/aws_aurora_backup:latest .
# example normal docker run: docker run --rm -it --env-file env-vars -e AWS_REGION='us-east-1' ericstephengarcia/aws_aurora_backup:latest bash

# Define global args
ARG FUNCTION_DIR="/app"

FROM public.ecr.aws/lambda/python:3.9

LABEL com.amazon.description='general python lambda container' \
    com.amazon.is-dev='0' \
    com.amazon.is-production='1' \
    com.amazon.maintainer='grmeri@amazon.com'
ENV PYTHONUNBUFFERED 1

# create function directory
RUN echo $PATH

# update all OS packages 
ENV PATH='/usr/local/bin:/usr/bin/:/bin:/opt/bin:/usr/sbin'
RUN yum -y update && yum -y install which amazon-linux-extras wget shadow-utils awscli unzip && \
amazon-linux-extras disable postgresql9.6 && amazon-linux-extras enable postgresql12 && \
yum -y install postgresql && yum -y clean all

ARG FUNCTION_DIR
ARG RUNTIME_VERSION

# create function directory
RUN mkdir -p ${FUNCTION_DIR}/python-modules
# copy handler function
COPY app ${FUNCTION_DIR}
# optional – install the function's dependencies
ENV PATH='/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin:/usr/sbin'
RUN python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org \
-r ${FUNCTION_DIR}/requirements.txt --target ${FUNCTION_DIR}/python-modules

# install v2 of the cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip ./aws

# sudo like tool to step down from root to a non-privileged user 
RUN gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

WORKDIR ${FUNCTION_DIR}
RUN chmod +x ${FUNCTION_DIR}/entry.sh
ENTRYPOINT ["./entry.sh"]