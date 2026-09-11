"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { ExternalLink, Search } from "lucide-react";

import { DashboardPageLayout } from "@/components/templates/DashboardPageLayout";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

type ProjectRecord = {
  name: string;
  repository: string;
  href: string;
  role: string;
  category: "Control plane" | "Execution" | "Runtime" | "Framework" | "Research";
  registryState: "Core" | "Available";
  description: string;
  capabilities: string[];
};

const PROJECTS: ProjectRecord[] = [
  {
    name: "OpenClaw Mission Control",
    repository: "PEFY-TECH/openclaw-mission-control",
    href: "https://github.com/PEFY-TECH/openclaw-mission-control",
    role: "Governance and operations control plane",
    category: "Control plane",
    registryState: "Core",
    description:
      "Central operating surface for organizations, boards, tasks, approvals, gateways, agents, activity and API-backed automation.",
    capabilities: ["Governance", "Approvals", "Audit trail", "Gateway operations"],
  },
  {
    name: "ClawTeam OpenClaw",
    repository: "PEFY-TECH/ClawTeam-OpenClaw",
    href: "https://github.com/PEFY-TECH/ClawTeam-OpenClaw",
    role: "Multi-agent execution and coordination plane",
    category: "Execution",
    registryState: "Core",
    description:
      "Coordinates agent teams with isolated worktrees, task dependencies, messaging, team templates and operational dashboards.",
    capabilities: ["Agent teams", "Worktrees", "Task DAG", "Team templates"],
  },
  {
    name: "OpenClaw",
    repository: "PEFY-TECH/openclaw",
    href: "https://github.com/PEFY-TECH/openclaw",
    role: "Agent runtime",
    category: "Runtime",
    registryState: "Core",
    description:
      "Registered runtime used by the PEFY agent workforce and available to the governed execution layer.",
    capabilities: ["Agent runtime", "CLI", "Skills", "Gateway integration"],
  },
  {
    name: "AgentScope",
    repository: "PEFY-TECH/agentscope",
    href: "https://github.com/PEFY-TECH/agentscope",
    role: "Agent framework candidate",
    category: "Framework",
    registryState: "Available",
    description:
      "Registered agent framework retained as a selectable capability source rather than an account-wide default.",
    capabilities: ["Agents", "Orchestration", "Framework"],
  },
  {
    name: "AutoAgent",
    repository: "PEFY-TECH/AutoAgent",
    href: "https://github.com/PEFY-TECH/AutoAgent",
    role: "Autonomous-agent framework candidate",
    category: "Framework",
    registryState: "Available",
    description:
      "Registered autonomous-agent implementation available for evaluation behind PEFY governance gates.",
    capabilities: ["Autonomy", "Agents", "Evaluation candidate"],
  },
  {
    name: "VoltAgent",
    repository: "PEFY-TECH/voltagent",
    href: "https://github.com/PEFY-TECH/voltagent",
    role: "Agent framework candidate",
    category: "Framework",
    registryState: "Available",
    description:
      "Registered framework candidate for agent services and orchestration workloads where it provides measurable advantage.",
    capabilities: ["Agents", "Services", "Orchestration"],
  },
  {
    name: "Archon",
    repository: "PEFY-TECH/Archon",
    href: "https://github.com/PEFY-TECH/Archon",
    role: "Agent-building capability",
    category: "Framework",
    registryState: "Available",
    description:
      "Registered agent-building project available for governed assessment and specialized agent creation workflows.",
    capabilities: ["Agent builder", "Knowledge", "Specialized workflows"],
  },
  {
    name: "Deer Flow",
    repository: "PEFY-TECH/deer-flow",
    href: "https://github.com/PEFY-TECH/deer-flow",
    role: "Research workflow candidate",
    category: "Research",
    registryState: "Available",
    description:
      "Registered research-oriented agent workflow available as a controlled capability source.",
    capabilities: ["Research", "Workflow", "Agent collaboration"],
  },
  {
    name: "Paperclip",
    repository: "PEFY-TECH/paperclip",
    href: "https://github.com/PEFY-TECH/paperclip",
    role: "Agent platform candidate",
    category: "Framework",
    registryState: "Available",
    description:
      "Registered platform candidate retained for evaluation and integration through PEFY-owned adapters where justified.",
    capabilities: ["Agents", "Platform", "Integration candidate"],
  },
];

const CATEGORIES = ["All", "Control plane", "Execution", "Runtime", "Framework", "Research"] as const;

type CategoryFilter = (typeof CATEGORIES)[number];

export default function ProjectGalleryPage() {
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState<CategoryFilter>("All");

  const filteredProjects = useMemo(() => {
    const query = search.trim().toLowerCase();
    return PROJECTS.filter((project) => {
      const categoryMatch = category === "All" || project.category === category;
      const queryMatch =
        !query ||
        [
          project.name,
          project.repository,
          project.role,
          project.description,
          project.category,
          ...project.capabilities,
        ]
          .join(" ")
          .toLowerCase()
          .includes(query);
      return categoryMatch && queryMatch;
    });
  }, [category, search]);

  return (
    <DashboardPageLayout
      signedOut={{
        message: "Sign in to access the PEFY AI Project Gallery.",
        forceRedirectUrl: "/project-gallery",
        signUpForceRedirectUrl: "/project-gallery",
      }}
      title="AI Project Gallery"
      description="Governed catalogue of PEFY agent, AI and orchestration projects. Registry presence does not by itself grant production approval."
      stickyHeader
    >
      <section className="space-y-6">
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="grid gap-4 lg:grid-cols-[1fr_auto] lg:items-center">
            <div className="relative max-w-2xl">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <Input
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Search projects, roles or capabilities"
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
        </div>

        <div className="grid gap-4 xl:grid-cols-2">
          {filteredProjects.map((project) => (
            <article
              key={project.repository}
              className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <div className="flex flex-wrap items-center gap-2">
                    <h2 className="font-heading text-lg font-semibold text-slate-900">
                      {project.name}
                    </h2>
                    <span
                      className={cn(
                        "rounded-full px-2 py-0.5 text-[11px] font-semibold",
                        project.registryState === "Core"
                          ? "bg-emerald-100 text-emerald-800"
                          : "bg-slate-100 text-slate-700",
                      )}
                    >
                      {project.registryState}
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

              <p className="mt-4 text-sm leading-6 text-slate-600">
                {project.description}
              </p>
              <p className="mt-3 font-mono text-xs text-slate-500">
                {project.repository}
              </p>

              <div className="mt-4 flex flex-wrap gap-2">
                {project.capabilities.map((capability) => (
                  <span
                    key={capability}
                    className="rounded-md bg-slate-100 px-2 py-1 text-xs text-slate-600"
                  >
                    {capability}
                  </span>
                ))}
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
          <h2 className="font-heading text-base font-semibold text-amber-950">
            External discovery source
          </h2>
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
