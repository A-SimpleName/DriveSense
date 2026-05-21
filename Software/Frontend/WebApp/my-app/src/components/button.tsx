import '../styles/button.css';

type ButtonProps = {
  className?: string;
  label: string;
  type?: "button" | "submit" | "reset";
  title?: string;
  onClick?: () => void;
  stopPropagation?: boolean;
};

export function Button({ className, label, type = "button", title, onClick, stopPropagation = false }: ButtonProps) {
  return (
    <button
      className={className}
      type={type}
      title={title}
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