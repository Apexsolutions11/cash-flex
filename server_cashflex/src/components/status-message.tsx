"use client"

import { CheckCircle2, X, AlertTriangle } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"

export type StatusMessageValue =
  | { type: "success" | "error"; text: string; title?: string }
  | null

export function StatusMessage({
  message,
  onDismiss,
}: {
  message: StatusMessageValue
  onDismiss?: () => void
}) {
  if (!message) return null

  const isSuccess = message.type === "success"
  const variant = isSuccess ? "default" : "destructive"
  const Icon = isSuccess ? CheckCircle2 : AlertTriangle

  return (
    <Alert
      variant={variant}
      className={[
        "flex items-start justify-between gap-3",
        isSuccess
          ? "border-emerald-200/70 bg-emerald-50/70 text-emerald-950 dark:border-emerald-900/50 dark:bg-emerald-950/25 dark:text-emerald-200 [&>svg]:text-emerald-600 dark:[&>svg]:text-emerald-400"
          : "",
      ].join(" ")}
    >
      <div className="relative w-full">
        <Icon className="h-4 w-4" />
        <div>
          <AlertTitle>{message.title ?? (isSuccess ? "Success" : "Error")}</AlertTitle>
          <AlertDescription>{message.text}</AlertDescription>
        </div>
      </div>
      {onDismiss && (
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="h-8 w-8 shrink-0"
          onClick={onDismiss}
          aria-label="Dismiss"
        >
          <X className="h-4 w-4" />
        </Button>
      )}
    </Alert>
  )
}


