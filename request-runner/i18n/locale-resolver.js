"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const config = JSON.parse(
  fs.readFileSync(path.join(ROOT, "config.json"), "utf8")
);

function normalize(locale) {
  if (!locale || typeof locale !== "string") {
    return config.defaultLocale;
  }

  try {
    const canonical = Intl.getCanonicalLocales(locale)[0];
    return canonical || config.defaultLocale;
  } catch {
    return config.defaultLocale;
  }
}

function resolveLocale(input) {
  const requested = normalize(input);

  const available = [
    config.defaultLocale,
    config.fallbackLocale,
    requested,
    requested.split("-")[0]
  ];

  return [...new Set(available)][0];
}

function direction(locale) {
  const language = normalize(locale).split("-")[0];

  return [
    "ar",
    "arc",
    "dv",
    "fa",
    "he",
    "ku",
    "ps",
    "ur",
    "yi"
  ].includes(language)
    ? "rtl"
    : "ltr";
}

module.exports = Object.freeze({
  normalize,
  resolveLocale,
  direction
});
