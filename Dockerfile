FROM dart:stable
RUN mkdir -p /opt/app
WORKDIR /opt/app
COPY ./build/web .
EXPOSE 8080
CMD sudo dart pub global activate dhttpd && sudo dart pub global run dhttpd --path . --port 8080 --host 0.0.0.0