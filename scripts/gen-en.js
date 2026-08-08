// Generates the English variant of the Elm app: src/Main.elm contains both
// language configs, with the English one disabled by the `{- English -}`
// comment marker. Flipping the marker comments out the Dutch config instead.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const source = readFileSync(resolve(root, 'src/Main.elm'), 'utf8')
mkdirSync(resolve(root, 'src-en'), { recursive: true })
writeFileSync(resolve(root, 'src-en/Main.elm'), source.replace('{- English -}', 'English {-'))
