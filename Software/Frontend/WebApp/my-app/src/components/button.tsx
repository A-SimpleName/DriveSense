import '../styles/button.css';

type ButtonProps = {
  className?: string;
  label: string;
  type?: "button" | "submit" | "reset";
  title?: string;
  onClick?: () => void;
  stopPropagation?: boolean;
  loading?: boolean;
  disabled?: boolean;
};

function ButtonSpinnerInline() {
  return (
    <span
      style={{
        display: "inline-block",
        width: "12px",
        height: "12px",
        border: "2px solid rgba(255,255,255,0.35)",
        borderTopColor: "currentColor",
        borderRadius: "50%",
        animation: "spin 0.6s linear infinite",
        verticalAlign: "middle",
        marginRight: "6px",
        flexShrink: 0,
      }}
    />
  );
}

export function Button({ className, label, type = "button", title, onClick, stopPropagation = false, loading = false, disabled }: ButtonProps) {
  return (
    <button
      className={className}
      type={type}
      title={title}
      disabled={disabled ?? loading}
      onClick={(e) => {
        if (stopPropagation) {
          e.stopPropagation();
        }
        onClick?.();
      }}
    >
      {loading && <ButtonSpinnerInline />}
      {label}
    </button>
  );
}
