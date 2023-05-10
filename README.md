This is a broker application in elixir that accepts tcp clients and servers, as well as pseudo-mqtt clients.

To run the project in docker use the following commands:

```
docker-compose build
docker-compose up
```
Beware that sometimes the rtp server may take a while to start accepting requests so I recommend turning the containers on manually to give it a few seconds to get its stuff in order.
