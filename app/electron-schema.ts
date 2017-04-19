import { DomElementSchemaRegistry } from '@angular/compiler';
import { SchemaMetadata } from '@angular/core';
const tags: Object = {
  webview: {
    src: true,
    autosize: true,
    nodeintegration: true,
    plugins: true,
    preload: true,
    httpreferrer: true,
    useragent: true,
    disablewebsecurity: true,
    partition: true,
    allowpopups: true,
    webpreferences: true,
    blinkfeatures: true,
    disableblinkfeatures: true,
    guestinstance: true,
    disableguestresize: true
  }
};

export const ELECTRON_SCHEMA: SchemaMetadata = {
  name: 'electron-schema'
};

DomElementSchemaRegistry.prototype.hasElement = new Proxy(DomElementSchemaRegistry.prototype.hasElement, {
  apply(target, thisArgument, argumentsList) {
    const [tagName, schemaMetas] = argumentsList;
    if (schemaMetas.some((schema: SchemaMetadata) => schema.name === ELECTRON_SCHEMA.name) && tags[tagName]) {
      return true;
    }
    return Reflect.apply(target, thisArgument, argumentsList);
  }
});
DomElementSchemaRegistry.prototype.hasProperty = new Proxy(DomElementSchemaRegistry.prototype.hasProperty, {
  apply(target, thisArgument, argumentsList) {
    const [tagName, propName, schemaMetas] = argumentsList;
    if (schemaMetas.some((schema: SchemaMetadata) => schema.name === ELECTRON_SCHEMA.name) && tags[tagName] && tags[tagName][propName]) {
      return true;
    }
    return Reflect.apply(target, thisArgument, argumentsList);
  }
});
