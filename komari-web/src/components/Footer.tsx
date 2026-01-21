import { Flex } from '@radix-ui/themes';

const Footer = () => {
  return (
    <div
      className='footer p-2 border-t-1 border-t-[var(--gray-7)]'
    >
      <Flex
        direction={{ initial: 'column', md: 'row' }}
        justify="between"
        align={{ initial: 'center', md: 'start' }}
        gap="4"
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
        }}
      >
        {/* Copyright and ICP Filing */}
        {/* <Flex direction="column" gap="2" align={{ initial: 'center', md: 'start' }}>
          <Text size="2" color="gray">
             Powered by SECUCY 
          </Text>
          {buildTime && (
            <Text size="1" color="gray">
              Build Time: {formatBuildTime(buildTime)}
            </Text>
          )}
          <Text size="1" color="gray">
            {versionInfo && `${versionInfo.version} (${versionInfo.hash})`}
          </Text>
        </Flex> */}

      </Flex>
    </div>
  );
};

export default Footer;

