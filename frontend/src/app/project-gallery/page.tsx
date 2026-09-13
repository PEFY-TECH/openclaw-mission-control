"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { CheckCircle2, CircleDashed, ExternalLink, Search, ShieldCheck } from "lucide-react";

import { DashboardPageLayout } from "@/components/templates/DashboardPageLayout";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

type ProjectCategory = "Control plane" | "Execution" | "Runtime" | "Framework" | "Research";
type RegistryState = "Core" | "Available";
type AssuranceState =
  | "Code qualified"
  | "Code gate pending"
  | "Runtime gate pending"
  | "Evaluation only";

type ProjectRecord = {
  name: string;
  repository: string;
  href: string;
  role: string;
  category: ProjectCategory;
  registryState: RegistryState;
  assuranceState: AssuranceState;
  description: string;
  capabilities: string[];
  evidence: string[];
  nextGate: string;
};

const PROJECTS: ProjectRecord[] = [
  {
    name: "OpenClaw Mission Control",
    repository: "PEFY-TECH/openclaw-mission-control",
    href: "https://github.com/PEFY-TECH/openclaw-mission-control",
    role: "Governance and operations control plane",
    category: "Control plane",
    registryState: "Core",
    assuranceState: "Code qualified",
    description:
      "Central operating surface for organizations, boards, tasks, approvals, gateways, agents, activity and API-backed automation.",
    capabilities: ["Governance", "Approvals", "Audit trail", "Gateway operations"],
    evidence: [
      "Backend and frontend CI passed",
      "Frontend build and tests passed",
      "Cypress E2E passed",
      "Linux/Docker and macOS installer smoke tests passed",
    ],
    nextGate: "Evidence a real production host, runtime health, controlled smoke mission and rollback target.",
  },
  {
    name: "ClawTeam OpenClaw",
    repository: "PEFY-TECH/ClawTeam-OpenClaw",
    href: "https://github.com/PEFY-TECH/ClawTeam-OpenClaw",
    role: "Multi-agent execution and coordination plane",
    category: "Execution",
    registryState: "Core",
    assuranceState: "Code gate pending",
    description:
      "Coordinates agent teams with isolated worktrees, task dependencies, messaging, team templates and operational dashboards.",
    capabilities: ["Agent teams", "Worktrees", "Task DAG", "Team templates"],
    evidence: [
      "Production qualifier hardened against unhealthy storage",
      "Concrete-agent OpenClaw allowlist required",
      "Regression qualification tests added",
      "P1 review findings remediated",
    ],
    nextGate: "Enable GitHub Actions, pass Ruff plus Ubuntu/macOS Python 3.10-3.12 matrix, then merge and qualify on the real host.",
  },
  {
    name: "OpenClaw",
    repository: "PEFY-TECH/openclaw",
    href: "https://github.com/PEFY-TECH/openclaw",
    role: "Default governed agent runtime",
    category: "Runtime",
    registryState: "Core",
    assuranceState: "Runtime gate pending",
    description:
      "Registered default runtime for the PEFY agent workforce. Runtime-active status is granted only after host-level verification.",
    capabilities: ["Agent runtime", "CLI", "Skills", "Gateway integration"],
    evidence: [
      "Repository registered as canonical runtime",
      "Execution policy requires allowlist mode",
      "ClawTeam skill presence is a production qualification gate",
    ],
    nextGate: "Verify production credentials, gateway connectivity, skill load, effective approvals, logs and auditable smoke execution.",
  },
  {
    name: "AgentScope",
    repository: "PEFY-TECH/agentscope",
    href: "https://github.com/PEFY-TECH/agentscope",
    role: "Agent framework candidate",
    category: "Framework",
    registryState: "Available",
    assuranceState: "Evaluation only",
    description:
      "Registered capability source retained behind PEFY governance rather than promoted as an account-wide default.",
    capabilities: ["Agents", "Orchestration", "Framework"],
    evidence: ["Registry presence only; no PEFY production certification is asserted."],
    nextGate: "Provenance, license, security, benchmark, interoperability and rollback qualification before promotion.",
  },
  {
    name: "AutoAgent",
    repository: "PEFY-TECH/AutoAgent",
    href: "https://github.com/PEFY-TECH/AutoAgent",
    role: "Autonomous-agent framework candidate",
    category: "Framework",
    registryState: "Available",
    assuranceState: "Evaluation only",
    description:
      "Registered autonomous-agent implementation available for controlled assessment behind PEFY-owned interfaces.",
    capabilities: ["Autonomy", "Agents", "Evaluation candidate"],
    evidence: ["Registry presence only; no PEFY production certification is asserted."],
    nextGate: "Provenance, license, security, benchmark, interoperability and rollback qualification before promotion.",
  },
  {
    name: "VoltAgent",
    repository: "PEFY-TECH/voltagent",
    href: "https://github.com/PEFY-TECH/voltagent",
    role: "Agent framework candidate",
    category: "Framework",
    registryState: "Available",
    assuranceState: "Evaluation only",
    description:
      "Registered framework candidate for workloads where testing can demonstrate a measurable advantage.",
    capabilities: ["Agents", "Services", "Orchestration"],
    evidence: ["Registry presence only; no PEFY production certification is asserted."],
    nextGate: "Provenance, license, security, benchmark, interoperability and rollback qualification before promotion.",
  },
  {
    name: "Archon",
    repository: "PEFY-TECH/Archon",
    href: "https://github.com/PEFY-TECH/Archon",
    role: "Agent-building capability",
    category: "Framework",
    registryState: "Available",
    assuranceState: "Evaluation only",
    description:
      "Registered agent-building project for controlled evaluation and specialized agent creation workflows.",
    capabilities: ["Agent builder", "Knowledge", "Specialized workflows"],
    evidence: ["Registry presence only; no PEFY production certification is asserted."],
    nextGate: "Provenance, license, security, benchmark, interoperability and rollback qualification before promotion.",
  },
  {
    name: "Deer Flow",
    repository: "PEFY-TECH/deer-flow",
    href: "https://github.com/PEFY-TECH/deer-flow",
    role: "Research workflow candidate",
    category: "Research",
    registryState: "Available",
    assuranceState: "Evaluation only",
    description:
      "Registered research-oriented workflow retained as a controlled capability source rather than a default runtime.",
    capabilities: ["Research", "Workflow", "Agent collaboration"],
    evidence: ["Registry presence only; no PEFY production certification is asserted."],
    nextGate: "Provenance, license, security, benchmark, interoperability and rollback qualification before promotion.",
  },
  {
    name: "Paperclip",
    repository: "PEFY-TECH/paperclip",
    href: "https://github.com/PEFY-TECH/paperclip",
    role: "Agent platform candidate",
    category: "Framework",
    registryState: "Available",
    assuranceState: "Evaluation only",
    description:
      "Registered platform candidate retained for evaluation through PEFY-owned adapters where justified by evidence.",
    capabilities: ["Agents", "Platform", "Integration candidate"],
    evidence: ["Registry presence only; no PEFY production certification is asserted."],
    nextGate: "Provenance, license, security, benchmark, interoperability and rollback qualification before promotion.",
  },
];

const CATEGORIES = ["All", "Control plane", "Execution", "Runtime", "Framework", "Research"] as const;
const ASSURANCE_FILTERS = [
  "All",
  "Code qualified",
  "Code gate pending",
  "Runtime gate pending",
  "Evaluation only",
] as const;

type CategoryFilter = (typeof CATEGORIES)[number];
type AssuranceFilter = (typeof ASSURANCE_FILTERS)[number];

function assuranceClass(state: AssuranceState) {
  if (state === "Code qualified") return "bg-emerald-100 text-emerald-800";
  if (state === "Evaluation only") return "bg-slate-100 text-slate-700";
  return "bg-amber-100 text-amber-900";
}

export default function ProjectGalleryPage() {
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState<CategoryFilter>("All");
  const [assurance, setAssurance] = useState<AssuranceFilter>("All");

  const filteredProjects = useMemo(() => {
    const query = search.trim().toLowerCase();
    return PROJECTS.filter((project) => {
      const categoryMatch = category === "All" || project.category === category;
      const assuranceMatch = assurance === "All" || project.assuranceState === assurance;
      const queryMatch =
        !query ||
        [
          project.name,
          project.repository,
          project.role,
          project.description,
          project.category,
          project.assuranceState,
          project.nextGate,
          ...project.capabilities,
          ...project.evidence,
        ]
          .join(" ")
          .toLowerCase()
          .includes(query);
      return categoryMatch && assuranceMatch && queryMatch;
    });
  }, [assurance, category, search]);

  const codeQualified = PROJECTS.filter((project) => project.assuranceState === "Code qualified").length;
  const corePending = PROJECTS.filter(
    (project) => project.registryState === "Core" && project.assuranceState !== "Code qualified",
  ).length;
  const evaluationOnly = PROJECTS.filter((project) => project.assuranceState === "Evaluation only").length;

  return (
    <DashboardPageLayout
      signedOut={{
        message: "Sign in to access the PEFY AI Project Gallery.",
        forceRedirectUrl: "/project-gallery",
        signUpForceRedirectUrl: "/project-gallery",
      }}
      title="AI Project Gallery"
      description="Governed catalogue with explicit evidence, promotion gates and runtime-readiness status. Registry presence never equals production approval."
      stickyHeader
    >
      <section className="space-y-6">
        <div className="grid gap-3 md:grid-cols-3">
          <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4">
            <div className="flex items-center gap-2 text-sm font-semibold text-emerald-900">
              <CheckCircle2 className="h-4 w-4" /> Code qualified
            </div>
            <p className="mt-2 text-2xl font-semibold text-emerald-950">{codeQualified}</p>
            <p className="mt-1 text-xs text-emerald-900/70">Qualified repository baseline; host runtime is evaluated separately.</p>
          </div>
          <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
            <div className="flex items-center gap-2 text-sm font-semibold text-amber-950">
              <CircleDashed className="h-4 w-4" /> Core gates pending
            </div>
            <p className="mt-2 text-2xl font-semibold text-amber-950">{corePending}</p>
            <p className="mt-1 text-xs text-amber-900/70">Core components still requiring CI or real-host evidence.</p>
          </div>
          <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
            <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
              <ShieldCheck className="h-4 w-4" /> Evaluation only
            </div>
            <p className="mt-2 text-2xl font-semibold text-slate-950">{evaluationOnly}</p>
            <p className="mt-1 text-xs text-slate-500">Available projects stay isolated until provenance and engineering gates pass.</p>
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="grid gap-4 lg:grid-cols-[1fr_auto] lg:items-center">
            <div className="relative max-w-2xl">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <Input
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Search projects, evidence, gates or capabilities"
                className="pl-9"
                aria-label="Search project gallery"
              />
            </div>
            <p className="text-sm text-slate-500">
              {filteredProjects.length} of {PROJECTS.length} registered projects
            </p>
          </div>

          <div className="mt-4 flex flex-wrap gap-2" aria-label="Project categories">
            {CATEGORIES.map((item) => (
              <button
                key={item}
                type="button"
                onClick={() => setCategory(item)}
                className={cn(
                  "rounded-full border px-3 py-1.5 text-xs font-medium transition",
                  category === item
                    ? "border-blue-600 bg-blue-600 text-white"
                    : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50",
                )}
              >
                {item}
              </button>
            ))}
          </div>

          <div className="mt-3 flex flex-wrap gap-2" aria-label="Assurance status">
            {ASSURANCE_FILTERS.map((item) => (
              <button
                key={item}
                type="button"
                onClick={() => setAssurance(item)}
                className={cn(
                  "rounded-full border px-3 py-1.5 text-xs font-medium transition",
                  assurance === item
                    ? "border-slate-900 bg-slate-900 text-white"
                    : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50",
                )}
              >
                {item}
              </button>
            ))}
          </div>
        </div>

        <div className="grid gap-4 xl:grid-cols-2">
          {filteredProjects.map((project) => (
            <article key={project.repository} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <div className="flex flex-wrap items-center gap-2">
                    <h2 className="font-heading text-lg font-semibold text-slate-900">{project.name}</h2>
                    <span
                      className={cn(
                        "rounded-full px-2 py-0.5 text-[11px] font-semibold",
                        project.registryState === "Core"
                          ? "bg-blue-100 text-blue-800"
                          : "bg-slate-100 text-slate-700",
                      )}
                    >
                      {project.registryState}
                    </span>
                    <span className={cn("rounded-full px-2 py-0.5 text-[11px] font-semibold", assuranceClass(project.assuranceState))}>
                      {project.assuranceState}
                    </span>
                  </div>
                  <p className="mt-1 text-xs font-medium uppercase tracking-wide text-slate-500">
                    {project.category} · {project.role}
                  </p>
                </div>
                <Link
                  href={project.href}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-2 text-xs font-medium text-slate-700 transition hover:bg-slate-50"
                >
                  Repository
                  <ExternalLink className="h-3.5 w-3.5" />
                </Link>
              </div>

              <p className="mt-4 text-sm leading-6 text-slate-600">{project.description}</p>
              <p className="mt-3 font-mono text-xs text-slate-500">{project.repository}</p>

              <div className="mt-4 flex flex-wrap gap-2">
                {project.capabilities.map((capability) => (
                  <span key={capability} className="rounded-md bg-slate-100 px-2 py-1 text-xs text-slate-600">
                    {capability}
                  </span>
                ))}
              </div>

              <div className="mt-5 grid gap-4 border-t border-slate-100 pt-4 md:grid-cols-2">
                <div>
                  <h3 className="text-xs font-semibold uppercase tracking-wide text-slate-500">Evidence</h3>
                  <ul className="mt-2 space-y-1.5 text-xs leading-5 text-slate-600">
                    {project.evidence.map((item) => (
                      <li key={item} className="flex gap-2">
                        <span aria-hidden="true">•</span>
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <div>
                  <h3 className="text-xs font-semibold uppercase tracking-wide text-slate-500">Next promotion gate</h3>
                  <p className="mt-2 text-xs leading-5 text-slate-600">{project.nextGate}</p>
                </div>
              </div>
            </article>
          ))}
        </div>

        {filteredProjects.length === 0 ? (
          <div className="rounded-xl border border-dashed border-slate-300 bg-white p-8 text-center text-sm text-slate-500">
            No registered project matches the current filters.
          </div>
        ) : null}

        <aside className="rounded-xl border border-amber-200 bg-amber-50 p-5">
          <h2 className="font-heading text-base font-semibold text-amber-950">External discovery source</h2>
          <p className="mt-2 text-sm leading-6 text-amber-900/80">
            KalyanM45/AI-Project-Gallery is tracked as an external reference only. At the governance review performed for this integration, GitHub exposed no declared repository license. Its content is therefore not mirrored, vendored, rebranded or promoted as PEFY-owned code.
          </p>
          <Link
            href="https://github.com/KalyanM45/AI-Project-Gallery"
            target="_blank"
            rel="noreferrer"
            className="mt-3 inline-flex items-center gap-1 text-sm font-semibold text-amber-950 underline underline-offset-4"
          >
            Open external reference
            <ExternalLink className="h-4 w-4" />
          </Link>
        </aside>
      </section>
    </DashboardPageLayout>
  );
}
