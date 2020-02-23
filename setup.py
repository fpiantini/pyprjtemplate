import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name = '<project_name>',
    packages = setuptools.find_packages(),
    version = '1.0.0',
    license = 'MIT',
    author = '<author_name>',
    author_email = '<author_email>',
    description = '<project_short_description>',
    long_description = long_description,
    long_description_content_type = 'text/markdown',
    url = '<project_url>',
    download_url = '<download_url>',
    install_requires=[
        # add required packages, e.g. numpy
        #'numpy',
        #'babel',
      ],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Development Status :: 3 - Alpha",  # Chose between:
                                            # "3 - Alpha"
                                            # "4 - Beta"
                                            # "5 - Production/Stable"
    ],
    python_requires='>=3.6',
)

