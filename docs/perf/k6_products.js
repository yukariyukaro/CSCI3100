import http from "k6/http"
import { check, sleep } from "k6"

export const options = {
  scenarios: {
    browse_products: {
      executor: "constant-vus",
      vus: __ENV.VUS ? parseInt(__ENV.VUS, 10) : 100,
      duration: __ENV.DURATION || "5m"
    }
  },
  thresholds: {
    http_req_failed: ["rate<0.001"],
    http_req_duration: ["p(99)<2000"]
  }
}

export default function () {
  const base = __ENV.BASE_URL || "http://localhost:3000"
  const slug = __ENV.COMMUNITY_SLUG || "chung-chi"

  const res1 = http.get(`${base}/${slug}/products`)
  check(res1, { "products index 200": (r) => r.status === 200 })

  const res2 = http.get(`${base}/${slug}/products/autocomplete?query=ma`)
  check(res2, { "autocomplete 200": (r) => r.status === 200 })

  sleep(1)
}

