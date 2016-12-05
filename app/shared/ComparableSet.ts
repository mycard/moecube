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
        for (var elem of subset) {
            if (!this.has(elem)) {
                return false;
            }
        }
        return true;
    }

    union(setB: Set<T>): Set<T> {
        var union = new Set(this);
        for (var elem of setB) {
            union.add(elem);
        }
        return union;
    }

    intersection(setB: Set<T>): Set<T> {
        var intersection = new Set();
        for (var elem of setB) {
            if (this.has(elem)) {
                intersection.add(elem);
            }
        }
        return intersection;
    }

    difference(setB: Set<T>): Set<T> {
        var difference = new Set(this);
        for (var elem of setB) {
            difference.delete(elem);
        }
        return difference;
    }
}
