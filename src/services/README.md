# Market Services #

## Production ##
This is the production cluster

#### Fedops Cluster ####
fedops connect --cluster=https://fedops.market.com/connect

[UserName]

[AccessKey]

## Staging ##

### Fedops Cluster ###
fedops connect --cluster=https://fedops.stag.market.com/connect

[UserName]

[AccessKey]

## Development ##

### Create a new Market cluster ###
Run `./init`

### Run the cluster ###
Run `./run`

# Architecture #

Market is micro service based.

## API Endpoints ##
## \*CREATE ##

#### Request ####
`POST` https://api.market.com/product

Headers

`AuthKey : 09dh101010h101h90dh19h1nd`

Payload

```
{
  "name" : "product name",
  "cost" : "$value",
  "zipcode" : 19211
}
```

#### Response ####
`STATUS 200 Ok`

```
{
  "uuid" : "n0911knjvbuaifafni11fj1afa"
}
```

`POST` https://api.market.com/producer

`POST` https://api.market.com/distributor

## \*UPDATE ##
`PUT` https://api.market.com/product

`PUT` https://api.market.com/producer

`PUT` https://api.market.com/distributor

## RETRIEVE ##
`GET` https://api.market.com/product

`GET` https://api.market.com/producer

`GET` https://api.market.com/distributor

## \*DESTROY ##
`DELETE` https://api.market.com/product

`DELETE` https://api.market.com/producer

`DELETE` https://api.market.com/distributor

### \*Requires Auth Headers ###
