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
