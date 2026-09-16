class Pipeline {
    constructor() {
        this.middleware = [];
    }

    use(handler) {
        this.middleware.push(handler);
        return this;
    }

    async execute(context, terminal = async () => context) {
        let index = -1;

        const dispatch = async (position, current) => {
            if (position <= index) {
                throw new Error("Middleware called next() multiple times");
            }

            index = position;

            const handler = this.middleware[position];

            if (!handler) {
                return terminal(current);
            }

            return handler(
                current,
                nextContext => dispatch(position + 1, nextContext)
            );
        };

        return dispatch(0, context);
    }
}

module.exports = Pipeline;
