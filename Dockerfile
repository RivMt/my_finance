FROM dart:stable
RUN mkdir -p /opt/app
WORKDIR /opt/app
COPY ./build/web .
RUN mkdir /.pub-cache
EXPOSE 8080
CMD dart pub global activate dhttpd && dart pub global run dhttpd --path . --port 8080 --host 0.0.0.0