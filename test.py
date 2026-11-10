from dotenv import load_dotenv
import os
load_dotenv(override=True)
print(os.environ['MONGODB_URI'])