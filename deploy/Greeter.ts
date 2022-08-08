export default async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    await deploy("Greeter", {
        from: deployer,
        args: ["Greeting"],
        log: true,
    });
};
