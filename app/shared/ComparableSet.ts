/**
 * Created by weijian on 2016/12/5.
 */
export class ComparableSet<T> extends Set<T> {
    constructor(values?: Iterable<T>) {
        if (values) {
            super(values);
        } else {
            super();
        }
    }

    isSuperset(subset: Set<T>) {
        for (let elem of subset) {
            if (!this.has(elem)) {
                return false;
            }
        }
        return true;
    }

    union(setB: Set<T>): Set<T> {
        let union = new Set(this);
        for (let elem of setB) {
            union.add(elem);
        }
        return union;
    }

    intersection(setB: Set<T>): Set<T> {
        let intersection = new Set();
        for (let elem of setB) {
            if (this.has(elem)) {
                intersection.add(elem);
            }
        }
        return intersection;
    }

    difference(setB: Set<T>): Set<T> {
        let difference = new Set(this);
        for (let elem of setB) {
            difference.delete(elem);
        }
        return difference;
    }
}
