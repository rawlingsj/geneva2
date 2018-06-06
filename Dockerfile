FROM scratch
EXPOSE 8080
ENTRYPOINT ["/geneva2"]
COPY ./bin/ /