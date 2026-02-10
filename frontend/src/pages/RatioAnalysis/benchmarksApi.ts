import { createApiUrl, getAuthHeaders } from "../../access/access";

export interface RatioBenchmarksResponse {
  benchmarks: Record<string, number | null>;
  labels: Record<string, string>;
  keys_order: string[];
}

export async function getRatioBenchmarks(): Promise<RatioBenchmarksResponse> {
  const url = createApiUrl("api/ratio-benchmarks/");
  const headers = await getAuthHeaders();
  const res = await fetch(url, { headers });
  if (!res.ok) throw new Error("Failed to fetch ratio benchmarks");
  return res.json();
}

export async function updateRatioBenchmarks(
  benchmarks: Record<string, number | null>
): Promise<{ status: string; message?: string }> {
  const url = createApiUrl("api/ratio-benchmarks/");
  const headers = await getAuthHeaders();
  const res = await fetch(url, {
    method: "PUT",
    headers,
    body: JSON.stringify({ benchmarks }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok)
    throw new Error(data.message || "Failed to update ratio benchmarks");
  return data;
}
