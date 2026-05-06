import '../styles/button.css';

type ButtonProps = {
  className?: string;
  label: string;
  type?: "button" | "submit" | "reset";
  onClick?: () => void;
  stopPropagation?: boolean;
};

export function Button({ className, label, type = "button", onClick, stopPropagation = false }: ButtonProps) {
  return (
    <button
      className={className}
      type={type}
      onClick={(e) => {
        if (stopPropagation) {
          e.stopPropagation();
        }
        onClick?.();
      }}
    >
      {label}
    </button>
  );
}