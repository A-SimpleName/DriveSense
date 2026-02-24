type Props = {
    type: string;
    name: string;
    text: string;
    value : string;
    onchange: (e: React.ChangeEvent<HTMLInputElement>) => void;
};

function Label({ type, name, text, value, onchange }: Props) {
    return (
        <div>
            <label htmlFor={name}>{text}</label>
            <input type={type} name={name} id={name} value={value} onChange={onchange} />
        </div>
     );
}

export default Label;