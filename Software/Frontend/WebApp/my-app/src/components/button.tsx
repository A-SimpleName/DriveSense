import '../styles/button.css';

type ButtonProps = {
  label: string;
  type?: "button" | "submit" | "reset";
  onClick?: () => void;
  stopPropagation?: boolean;
};

export function Button({ label, type, onClick, stopPropagation = false }: ButtonProps) {
  return (
    <button type={type} onClick={(e) => {
      if (stopPropagation) {
        e.stopPropagation();
        onClick?.();
      }
      }}>
      {label}
    </button>
  );
}