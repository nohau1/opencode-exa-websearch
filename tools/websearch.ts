import { tool } from "@opencode-ai/plugin"
import { execFile } from "node:child_process"
import { promisify } from "node:util"
import path from "node:path"
import os from "node:os"

const execFileAsync = promisify(execFile)

const SCRIPT =
  process.env.EXA_SEARCH_SCRIPT ??
  path.join(os.homedir(), ".config", "opencode", "scripts", "exa-search.sh")

type ExaResult = {
  title?: string
  url?: string
  author?: string
  publishedDate?: string
  highlights?: string[]
}

type ExaResponse = {
  requestId?: string
  results?: ExaResult[]
  error?: string
}

async function runExa(query: string, numResults: number): Promise<ExaResponse> {
  const { stdout } = await execFileAsync("bash", [SCRIPT, query, String(numResults)], {
    maxBuffer: 32 * 1024 * 1024,
    timeout: 90_000,
  })
  try {
    return JSON.parse(stdout) as ExaResponse
  } catch {
    throw new Error(`Exa returned non-JSON: ${stdout.slice(0, 500)}`)
  }
}

function format(res: ExaResponse): string {
  if (res.error) return `Exa error: ${res.error}`
  const results = res.results ?? []
  if (results.length === 0) return "No results found."

  return results
    .map((r, i) => {
      const lines = [`${i + 1}. ${r.title ?? "(no title)"}`, `   ${r.url ?? ""}`]
      if (r.author) lines.push(`   Author: ${r.author}`)
      if (r.publishedDate) lines.push(`   Published: ${r.publishedDate}`)
      const highlights = (r.highlights ?? [])
        .map((h) => h.replace(/\s+/g, " ").trim())
        .filter(Boolean)
        .slice(0, 3)
      for (const h of highlights) lines.push(`   > ${h}`)
      return lines.join("\n")
    })
    .join("\n\n")
}

export default tool({
  description:
    "Search the internet via the Exa API. Optionally routed through a SOCKS5 proxy to " +
    "work around Cloudflare blocking. Returns titles, URLs and highlighted snippets for " +
    "the top web results. Use this for any current/factual web lookup.",
  args: {
    query: tool.schema.string().describe("The search query"),
    numResults: tool.schema
      .number()
      .int()
      .min(1)
      .max(20)
      .optional()
      .describe("Number of results to return (default 8)"),
  },
  async execute(args) {
    const num = args.numResults ?? 8
    try {
      return format(await runExa(args.query, num))
    } catch (e) {
      return `Web search failed: ${e instanceof Error ? e.message : String(e)}`
    }
  },
})
