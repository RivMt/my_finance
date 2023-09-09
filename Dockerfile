FROM dart:stable
RUN mkdir -p /opt/app
WORKDIR /opt/app
COPY ./build/web .
COPY ./init.sh ..
RUN chmod +x ../init.sh
RUN ../init.sh
EXPOSE 8080
CMD dart pub global run dhttpd --path . --port 8080 --host 0.0.0.0