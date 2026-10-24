import type { ComponentProps } from "react";

export const inputClassName =
  "border-input bg-background focus-visible:border-ring focus-visible:ring-ring/40 h-10 w-full rounded-md border px-3 text-sm outline-none focus-visible:ring-3";

export const labelClassName = "grid gap-2 text-sm font-medium";

export function ErrorMessage({ message }: Readonly<{ message?: string }>) {
  if (!message) {
    return null;
  }

  return (
    <p
      className="border-destructive/30 bg-destructive/10 text-destructive rounded-md border px-3 py-2 text-sm"
      role="alert"
    >
      {message}
    </p>
  );
}

export function TextInput(props: ComponentProps<"input">) {
  return <input className={inputClassName} {...props} />;
}

export function SelectInput(props: ComponentProps<"select">) {
  return <select className={inputClassName} {...props} />;
}
