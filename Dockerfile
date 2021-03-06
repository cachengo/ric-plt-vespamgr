#
#  Copyright (c) 2019 AT&T Intellectual Property.
#  Copyright (c) 2018-2019 Nokia.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#   This source code is part of the near-RT RIC (RAN Intelligent Controller)
#   platform project (RICP).
#
# Start from golang v1.12 base image
FROM golang:1.12 as gobuild

# Set the Working Directory for ves-agent inside the container
RUN mkdir -p $GOPATH/src/VESPA
WORKDIR $GOPATH/src/VESPA

# Clone VES Agent v0.3.0 from github
RUN git clone -b v0.3.0 https://github.com/nokia/ONAP-VESPA.git $GOPATH/src/VESPA

RUN GO111MODULE=on go mod download

# Install VES Agent
RUN export GOPATH=$HOME/go && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    go install -v ./ves-agent

# Set the Working Directory for vesmgr inside the container
RUN mkdir -p $GOPATH/src/vesmgr
WORKDIR $GOPATH/src/vesmgr

# Copy vesmgr to the Working Directory
COPY $HOME/ .

RUN ./build_vesmgr.sh

#################
#
# Second phase, copy compiled stuff to a runtime container

# Ubuntu or something smaller?
FROM ubuntu:18.04
# For trouble-shooting
RUN apt-get update; apt-get install -y \
    iputils-ping \
    net-tools \
    curl \
    tcpdump

# Create the configuration directory for ves agent
RUN mkdir -p /etc/ves-agent
COPY --from=gobuild root/go/bin /root/go/bin

ENV PATH="/root/go/bin:${PATH}"

ENTRYPOINT ["vesmgr"]
