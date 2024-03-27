metadata description = 'Create database resources.'

param serverName string
param databaseName string

param location string = resourceGroup().location
param tags object = {}
