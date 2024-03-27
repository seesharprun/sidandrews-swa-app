metadata description = 'Create API application resources.'

param appName string

param serviceTag string
param location string = resourceGroup().location
param tags object = {}
