import random
import sys

from listing_0065_haversine_formula import reference_haversine


def random_point(x0: (float, float), y0: (float, float), x1: (float, float), y1: (float, float)) -> tuple:
    X0 = random.uniform(x0[0], x0[1])
    Y0 = random.uniform(y0[0], y0[1])
    X1 = random.uniform(x1[0], x1[1])
    Y1 = random.uniform(y1[0], y1[1])
    return X0, Y0, X1, Y1


if __name__ == '__main__':
    # check for 3 args, method, count and seed
    if len(sys.argv) != 4:
        print("Usage: haversine_generator_main.py <method> <count> <seed>")
        sys.exit(1)

    method = sys.argv[1]
    count = int(sys.argv[2])
    seed = int(sys.argv[3])

    if method not in ['cluster', 'uniform']:
        print("Method must be either 'cluster' or 'uniform', using uniform be default")
        method = 'uniform'

    if method == 'uniform':
        ranges = [((-180, 180), (-90, 90), (-180, 180), (-90, 90))]
    else:
        # todo calculate multiple ranges (clusters)
        num_of_clusters = random.randint(3, 10)
        ranges = []
        for i in range(num_of_clusters):
            x0 = (random.uniform(-180, 180), random.uniform(-180, 180))
            y0 = (random.uniform(-90, 90), random.uniform(-90, 90))
            x1 = (random.uniform(-180, 180), random.uniform(-180, 180))
            y1 = (random.uniform(-90, 90), random.uniform(-90, 90))
            ranges.append((x0, y0, x1, y1))

    sum_coefficient = 1.0 / count
    total = 0.0
    with open('haversine_data.json', 'w') as f:
        f.write('{"pairs":[\n')

        for i in range(count):
            x0, y0, x1, y1 = random_point(*ranges[0])
            distance = reference_haversine(x0, y0, x1, y1)
            total += distance * sum_coefficient

            f.write(f'{{"x0":{x0},"y0":{y0},"x1":{x1},"y1":{y1}}}')

            if i < count - 1:
                f.write(',\n')
            else:
                f.write('\n')

        f.write(']}')

    print(f"Method: {method}")
    print(f"Seed: {seed}")
    print(f"Count: {count}")
    print(f"Total distance: {total}")
