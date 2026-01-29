type Props = {
    type: string;
    name: string;
    text: string;
};

function Label({ type, name, text }: Props) {
    return ( 
        <form>
            <label htmlFor={name}>{text}</label>
            <input type={type} name={name} id={name} />
        </form>
     );
}

export default Label;