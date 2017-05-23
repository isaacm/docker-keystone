FROM python:2.7
MAINTAINER krystism "krystism@gmail.com"

ENV VERSION=10.0.0.0rc1

RUN set -x \
    && apt-get -y update \
    && apt-get install -y libffi-dev python-dev libssl-dev mysql-client python-mysqldb \
    && apt-get -y clean

RUN curl -fSL https://github.com/openstack/keystone/archive/${VERSION}.tar.gz -o keystone-${VERSION}.tar.gz \
    && tar xvf keystone-${VERSION}.tar.gz \
    && cd keystone-${VERSION} \
    && pip install -r requirements.txt \
    && PBR_VERSION=${VERSION}  pip install . \
    && pip install uwsgi MySQL-python \
    && cp -r etc /etc/keystone \
    && pip install python-openstackclient \
    && cd - \
    && rm -rf keystone-${VERSION}*

RUN git clone -b fix-imports https://github.com/isaacm/keystone-oauth2-extension.git
RUN cp -Rv keystone-oauth2-extension/oauth2 /usr/local/lib/python2.7/site-packages/keystone/contrib
RUN cp -v keystone-oauth2-extension/tests/* /usr/local/lib/python2.7/site-packages/keystone/tests
RUN cp -v keystone-oauth2-extension/plugins/oauth2.py /usr/local/lib/python2.7/site-packages/keystone/auth/plugins

COPY keystone.conf /etc/keystone/keystone.conf
COPY keystone.sql /root/keystone.sql
COPY keystone-paste.ini /etc/keystone/keystone-paste.ini
COPY policy.json /etc/keystone/policy.json

# Add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && chmod a+x /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
EXPOSE 5000 35357

HEALTHCHECK --interval=10s --timeout=5s \
  CMD curl -f http://localhost:5000/v3 2> /dev/null || exit 1; \
  curl -f http://localhost:35357/v3 2> /dev/null || exit 1; \
