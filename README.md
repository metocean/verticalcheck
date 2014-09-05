# Vertical Check

> Are you up or down?

Given a configuration file `verticalcheck.cson` such as the following.

```cson
[
  {
    dns:
      'google.co.nz': [
        '131.203.3.159'
        '131.203.3.187'
        '131.203.3.170'
        '131.203.3.165'
        '131.203.3.152'
        '131.203.3.174'
        '131.203.3.144'
        '131.203.3.185'
        '131.203.3.176'
        '131.203.3.148'
        '131.203.3.155'
        '131.203.3.166'
        '131.203.3.181'
        '131.203.3.177'
        '131.203.3.163'
        '131.203.3.154'
    ]
    ping: ['google.co.nz']
    http: [
      'http://google.co.nz/': 301
    ]
  }
]
```

Running `verticalcheck` on the command line will display the following.

```

   Vertical Check -- Are you up or down?

 √ dns entry google.co.nz resolves to 16 known ip addresses
 √ ping google.co.nz is up
 √ http http://google.co.nz/ is web'd

   fin.

```

Running `verticalcheck --json will display ` will display the following.

```json
[ { check: 'dns',
    isUp: true,
    param: 'google.co.nz',
    message: 'dns entry google.co.nz resolves to 16 known ip addresses' },
  { check: 'ping',
    isUp: true,
    param: 'google.co.nz',
    message: 'ping google.co.nz is up' },
  { check: 'http',
    isUp: true,
    param: 'http://google.co.nz/',
    message: 'http http://google.co.nz/ is web\'d' } ]
```