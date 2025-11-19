# gitlab-runner
Local docker gitlab runner.


## Setup:

Start with `docker-compose up -d` 
Then register the runner on gitlab `docker exec -it gitlab-runner gitlab-runner register`
Follow the steps given.

## Change the config file:

`sudo nano config/config.toml`

Change the variable Concurrent to: concurrent = 4
Save and exit the file.

Next restart the gitlab runner.

`docker-compose restart`


## Docker runner.
When selected the docker runner during registering of the gitlab-runner
Make sure to edit the created config.toml
[runners.docker]
  volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
