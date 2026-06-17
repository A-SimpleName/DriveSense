import { useRef } from "react";
import type { MouseEvent as ReactMouseEvent, TouchEvent as ReactTouchEvent, WheelEvent as ReactWheelEvent } from "react";

/**
 * Macht ein horizontal scrollbares Element per Mausrad, Maus-Drag und
 * Touch-Drag bedienbar (z.B. breite Tabellen wie in TripsTable).
 *
 * Verwendung:
 *   const dragScroll = useDragScroll<HTMLDivElement>();
 *   <div ref={dragScroll.ref} {...dragScroll.handlers}>...</div>
 */
export function useDragScroll<T extends HTMLElement = HTMLDivElement>() {
    const ref = useRef<T>(null);

    const onWheel = (e: ReactWheelEvent<T>) => {
        const el = e.currentTarget;
        const delta = e.deltaY || e.deltaX;

        if (delta !== 0) {
            e.preventDefault();
            el.scrollLeft += delta;
        }
    };

    const onMouseDown = (e: ReactMouseEvent<T>) => {
        const el = e.currentTarget;
        const startX = e.pageX;
        const startScrollLeft = el.scrollLeft;

        const onMouseMove = (moveEvent: MouseEvent) => {
            el.scrollLeft = startScrollLeft - (moveEvent.pageX - startX);
        };

        const onMouseUp = () => {
            document.removeEventListener("mousemove", onMouseMove);
            document.removeEventListener("mouseup", onMouseUp);
        };

        document.addEventListener("mousemove", onMouseMove);
        document.addEventListener("mouseup", onMouseUp);
    };

    const onTouchStart = (e: ReactTouchEvent<T>) => {
        const el = e.currentTarget;
        const touch = e.touches[0];
        const startX = touch.pageX;
        const startScrollLeft = el.scrollLeft;

        const onTouchMove = (moveEvent: TouchEvent) => {
            const currentTouch = moveEvent.touches[0];
            el.scrollLeft = startScrollLeft - (currentTouch.pageX - startX);
        };

        const onTouchEnd = () => {
            el.removeEventListener("touchmove", onTouchMove);
            el.removeEventListener("touchend", onTouchEnd);
        };

        el.addEventListener("touchmove", onTouchMove, { passive: true });
        el.addEventListener("touchend", onTouchEnd, { passive: true });
    };

    return {
        ref,
        handlers: { onWheel, onMouseDown, onTouchStart },
    };
}
