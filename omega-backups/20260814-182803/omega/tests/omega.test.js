import test from "node:test"
import assert from "node:assert/strict"
import {parseOmega} from "../src/parser.js"

test(
 "OMEGA parser",
 ()=>{
  const result=parseOmega(`
omega "TEST"

system {
 version "1.0.0"
 mode adaptive
}
`)

  assert.equal(result.name,"TEST")
  assert.equal(result.system.version,"1.0.0")
  assert.equal(result.system.mode,"adaptive")
 }
)
