import yaml

class ReliabilityConfig:
    def __init__(self, filename):
        if (filename):
            self.config_file = filename
        else:
            self.config_file = "./config.yaml"
        self.config = []

    def load_config(self):
        f = open(self.config_file)
        self.config = yaml.load(f)

if __name__ == "__main__":
    rc = ReliabilityConfig("/home/mifiedle/mffiedler_git/svt/reliability/nextgen/config/simple_reliability.yaml")
    rc.load_config()
    y = rc.config
    print(y['reliability'])
