export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="flex flex-1 items-center justify-center p-8">
      <div className="grid w-full max-w-sm gap-6">{children}</div>
    </main>
  );
}
