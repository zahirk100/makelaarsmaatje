export function Logo({ size = 36 }: { size?: number }) {
  return (
    <div
      style={{ width: size, height: size, background: "#1F3D2B", borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}
    >
      <svg width={size * 0.6} height={size * 0.6} viewBox="0 0 24 24" fill="none">
        <path d="M12 3L3 10V21H9V15H15V21H21V10L12 3Z" fill="#E8C07D" stroke="#E8C07D" strokeWidth="0.5" strokeLinejoin="round" />
        <circle cx="12" cy="13" r="1.2" fill="#1F3D2B" />
      </svg>
    </div>
  );
}
